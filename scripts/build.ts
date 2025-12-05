import { promises as fs } from 'fs';
import path from 'path';
import { execSync } from 'child_process';

interface PackageJson {
    name: string;
    version?: string;
    dependencies?: Record<string, string>;
    devDependencies?: Record<string, string>;
}

const packagesDir = path.resolve(__dirname, '..', 'packages');

async function getPackages(): Promise<Record<string, PackageJson>> {
    const dirs = await fs.readdir(packagesDir);
    const pkgs: Record<string, PackageJson> = {};

    for (const dir of dirs) {
        const pkgPath = path.join(packagesDir, dir, 'package.json');
        try {
            const content = await fs.readFile(pkgPath, 'utf-8');
            const json = JSON.parse(content) as PackageJson;
            pkgs[json.name] = json;
        } catch {
            // 跳过没有 package.json 的目录
        }
    }
    return pkgs;
}

// 拓扑排序，保证依赖先构建
function topoSort(pkgs: Record<string, PackageJson>): string[] {
    const visited = new Set<string>();
    const result: string[] = [];

    function visit(name: string) {
        if (visited.has(name)) return;
        visited.add(name);

        const deps = {};
        if (pkgs[name]?.dependencies) {
            Object.assign(deps, pkgs[name].dependencies);
        }
        if (pkgs[name]?.devDependencies) {
            Object.assign(deps, pkgs[name].devDependencies);
        }
        for (const dep of Object.keys(deps)) {
            if (pkgs[dep]) {
                visit(dep);
            }
        }
        result.push(name);
    }

    for (const name of Object.keys(pkgs)) {
        visit(name);
    }

    return result;
}

async function main() {
    const pkgs = await getPackages();
    const order = topoSort(pkgs);

    console.log('📦 构建顺序:', order.join(' -> '));

    for (const name of order) {
        console.log(`🚀 构建 ${name}...`);
        const pkgDir = path.join(packagesDir, name.replace(/^@.+\//, '')); // 去掉作用域前缀
        execSync('bun run build', { cwd: pkgDir, stdio: 'inherit' });
    }

    console.log('✅ 全部构建完成！');
}

main().catch((err) => {
    console.error('构建失败:', err);
    process.exit(1);
});
